/*
 * DebuKViz - Kieler Debug Visualization
 * 
 * A part of OpenKieler
 * https://github.com/OpenKieler
 * 
 * Copyright 2014 by
 * + Christian-Albrechts-University of Kiel
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.debukviz.util;

import org.eclipse.debug.core.DebugException;
import org.eclipse.debug.core.model.IVariable;
import org.eclipse.elk.core.options.CoreOptions;
import org.eclipse.elk.core.options.EdgeLabelPlacement;
import org.eclipse.elk.core.options.PortSide;

import com.google.inject.Guice;
import com.google.inject.Injector;

import de.cau.cs.kieler.debukviz.VariableTransformationContext;
import de.cau.cs.kieler.klighd.kgraph.KEdge;
import de.cau.cs.kieler.klighd.kgraph.KLabel;
import de.cau.cs.kieler.klighd.kgraph.KNode;
import de.cau.cs.kieler.klighd.kgraph.KPort;
import de.cau.cs.kieler.klighd.kgraph.util.KGraphUtil;
import de.cau.cs.kieler.klighd.krendering.KPolyline;
import de.cau.cs.kieler.klighd.krendering.KRectangle;
import de.cau.cs.kieler.klighd.krendering.KRenderingFactory;
import de.cau.cs.kieler.klighd.krendering.extensions.KColorExtensions;
import de.cau.cs.kieler.klighd.krendering.extensions.KPolylineExtensions;
import de.cau.cs.kieler.klighd.krendering.extensions.KRenderingExtensions;

/**
 * A builder that creates edges to visualizes relationships between variables. Transformations should
 * use this builder to end up with consistent looking diagrams. Start by obtaining an edge builder
 * through one of the static creation methods. Then, chain configuration method calls to configure the
 * edge to be built. Finally, call {@link #build()} to obtain the configured edge.
 * 
 * <p><em>Note:</em> The methods in this class will throw a {@link NullPointerException} if at least one
 * argument is {@code null}. Also, the edge builder will not check if the configuration is valid while
 * the configuration methods are called. Instead, a validity check is done when the edge is built.</p>
 */
public final class EdgeBuilder {
    
    /** The context of the transformation this builder is used in. */
    private VariableTransformationContext context = null;
    /** The edge's source node. */
    private KNode sourceNode = null;
    /** The edge's source port. */
    private KPort sourcePort = null;
    /** Whether to build a source port for the edge. */
    private boolean addSourcePort = false;
    /** The side of the source port to create. */
    private PortSide sourcePortSide = null;
    /** The index of the source port to create. */
    private int sourcePortIndex = 0;
    /** The edge's target node. */
    private KNode targetNode = null;
    /** The edge's target port. */
    private KPort targetPort = null;
    /** Whether to build a target port for the edge. */
    private boolean addTargetPort = false;
    /** The side of the target port to create. */
    private PortSide targetPortSide = null;
    /** The index of the target port to create. */
    private int targetPortIndex = 0;
    /** A label displayed at the head of the edge. */
    private String headLabel = null;
    /** A label displayed along the edge. */
    private String centerLabel = null;
    /** A label displayed at the tail of the edge. */
    private String tailLabel = null;
    /** Whether the edge is undirected, which will omit the arrow. */
    private boolean undirected = false;

    // KRendering extensions used to build the node rendering; initialized lazily
    private static KRenderingFactory renderingFactory = null;
    private static KColorExtensions colExt = null;
    private static KPolylineExtensions lineExt = null;
    private static KRenderingExtensions rendExt = null;
    
    
    ///////////////////////////////////////////////////////
    // Constructor / Create Methods
    
    /**
     * Private constructor. Obtain new instances through the static creation methods.
     */
    private EdgeBuilder() {
        
    }
    
    /**
     * Creates a new edge builder associated with the given transformation context.
     * 
     * @param context context of the transformation the builder is used in.
     * @return the edge builder.
     */
    public static EdgeBuilder forContext(final VariableTransformationContext context) {
        if (context == null) {
            throw new NullPointerException("context cannot be null");
        }
        
        EdgeBuilder builder = new EdgeBuilder();
        builder.context = context;
        
        return builder;
    }
    
    /**
     * Make a port of the same style as used when building edges.
     * 
     * @param portSide the side to assign to the new port
     * @param index the index to assign to the new port
     * @return a new port
     */
    public static KPort makePort(PortSide portSide, int index) {
        EdgeBuilder builder = new EdgeBuilder();
        builder.injectExtensions();
        return builder.buildPort(portSide, index);
    }

    
    ///////////////////////////////////////////////////////
    // Configuration
    
    /**
     * Configures the edge to originate at the node associated with the given variable. This method
     * assumes that the corresponding node already exists and will not trigger a transformation. If the
     * node does not exist, the configuration check will fail when building the edge.
     * 
     * @param variable the source variable
     * @return this builder.
     * @throws DebugException if something goes wrong when accessing the debug framework.
     */
    public EdgeBuilder from(IVariable variable) throws DebugException {
        if (variable == null) {
            throw new NullPointerException("variable cannot be null");
        }
        
        sourceNode = context.findAssociation(variable);
        return this;
    }
    
    /**
     * Configures the edge to originate at the given node.
     * 
     * @param node source node.
     * @return this builder.
     */
    public EdgeBuilder from(KNode node) {
        if (node == null) {
            throw new NullPointerException("node cannot be null");
        }
        
        sourceNode = node;
        return this;
    }
    
    /**
     * Configures the edge to originate at the given port. This method assumes that the port belongs to
     * a node. If it doesn't, the configuration check will fail when building the edge.
     * 
     * @param port source port.
     * @return this builder.
     */
    public EdgeBuilder from(KPort port) {
        if (port == null) {
            throw new NullPointerException("port cannot be null");
        }
        
        sourcePort = port;
        sourceNode = sourcePort.getNode();
        return this;
    }
    
    /**
     * Adds a source port at the given side. This has no effect if a source port is specified
     * explicitly. The port side is considered only if the port constraints of the source node
     * are set to FIXED_SIDE or stricter. The index is considered only if they are set to
     * FIXED_ORDER or stricter. 
     * 
     * @param portSide the node side on which the port shall be placed
     * @param index the clockwise index of the port for ordering the node's ports
     * @return this builder.
     */
    public EdgeBuilder addSourcePort(PortSide portSide, int index) {
        if (portSide == null) {
            throw new NullPointerException("portSide cannot be null");
        }
        
        addSourcePort = true;
        sourcePortSide = portSide;
        sourcePortIndex = index;
        
        return this;
    }
    
    /**
     * Adds a target port at the given side. This has no effect if a target port is specified
     * explicitly. The port side is considered only if the port constraints of the target node
     * are set to FIXED_SIDE or stricter. The index is considered only if they are set to
     * FIXED_ORDER or stricter. 
     * 
     * @param portSide the node side on which the port shall be placed
     * @param index the clockwise index of the port for ordering the node's ports
     * @return this builder.
     */
    public EdgeBuilder addTargetPort(PortSide portSide, int index) {
        if (portSide == null) {
            throw new NullPointerException("portSide cannot be null");
        }
        
        addTargetPort = true;
        targetPortSide = portSide;
        targetPortIndex = index;
        
        return this;
    }
    
    /**
     * Configures the edge to end at the node associated with the given variable. This method
     * assumes that the corresponding node already exists and will not trigger a transformation. If the
     * node does not exist, the configuration check will fail when building the edge.
     * 
     * @param variable the arget variable
     * @return this builder.
     * @throws DebugException if something goes wrong when accessing the debug framework.
     */
    public EdgeBuilder to(IVariable variable) throws DebugException {
        if (variable == null) {
            throw new NullPointerException("variable cannot be null");
        }
        
        targetNode = context.findAssociation(variable);
        return this;
    }
    
    /**
     * Configures the edge to end at the given node.
     * 
     * @param node source node.
     * @return this builder.
     */
    public EdgeBuilder to(KNode node) {
        if (node == null) {
            throw new NullPointerException("node cannot be null");
        }
        
        targetNode = node;
        return this;
    }
    
    /**
     * Configures the edge to end at the given port. This method assumes that the port belongs to
     * a node. If it doesn't, the configuration check will fail when building the edge.
     * 
     * @param port target port.
     * @return this builder.
     */
    public EdgeBuilder to(KPort port) {
        if (port == null) {
            throw new NullPointerException("port cannot be null");
        }
        
        targetPort = port;
        targetNode = targetPort.getNode();
        return this;
    }
    
    /**
     * Adds a head label with the given text to the edge.
     * 
     * @param label the label text.
     * @return this builder.
     */
    public EdgeBuilder headLabel(final String label) {
        if (label == null) {
            throw new NullPointerException("label cannot be null");
        }
        
        headLabel = label;
        return this;
    }
    
    /**
     * Adds a center label with the given text to the edge.
     * 
     * @param label the label text.
     * @return this builder.
     */
    public EdgeBuilder centerLabel(final String label) {
        if (label == null) {
            throw new NullPointerException("label cannot be null");
        }
        
        centerLabel = label;
        return this;
    }
    
    /**
     * Adds a tail label with the given text to the edge.
     * 
     * @param label the label text.
     * @return this builder.
     */
    public EdgeBuilder tailLabel(final String label) {
        if (label == null) {
            throw new NullPointerException("label cannot be null");
        }
        
        tailLabel = label;
        return this;
    }
    
    /**
     * Makes the edge undirected by omitting the arrow at the head of the edge.
     * 
     * @return this builder.
     */
    public EdgeBuilder undirected() {
        undirected = true;
        return this;
    }

    
    ///////////////////////////////////////////////////////
    // Building
    
    /**
     * Checks the builder's configuration and builds the edge.
     * 
     * @return the edge.
     * @throws IllegalStateException if the configuration is invalid.
     */
    public KEdge build() {
        checkConfiguration();
        
        // Prepare rendering extensions
        injectExtensions();
        
        // Build the edge
        KEdge edge = KGraphUtil.createInitializedEdge();
        
        edge.setSource(sourceNode);
        if (sourcePort != null) {
            edge.setSourcePort(sourcePort);
        } else if (addSourcePort) {
            KPort port = buildPort(sourcePortSide, sourcePortIndex);
            port.setNode(sourceNode);
            edge.setSourcePort(port);
        }
        
        edge.setTarget(targetNode);
        if (targetPort != null) {
            edge.setTargetPort(targetPort);
        } else if (addTargetPort) {
            KPort port = buildPort(targetPortSide, targetPortIndex);
            port.setNode(targetNode);
            edge.setTargetPort(port);
        } else {
            edge.setTargetPort(context.findDefaultInputPort(targetNode));
        }
        
        // Add labels
        if (centerLabel != null) {
            KLabel label = KGraphUtil.createInitializedLabel(edge);
            label.setText(centerLabel);
            label.setProperty(CoreOptions.EDGE_LABELS_PLACEMENT, EdgeLabelPlacement.CENTER);
        }
        
        if (tailLabel != null) {
            KLabel label = KGraphUtil.createInitializedLabel(edge);
            label.setText(tailLabel);
            label.setProperty(CoreOptions.EDGE_LABELS_PLACEMENT, EdgeLabelPlacement.TAIL);
        }
        
        if (headLabel != null) {
            KLabel label = KGraphUtil.createInitializedLabel(edge);
            label.setText(headLabel);
            label.setProperty(CoreOptions.EDGE_LABELS_PLACEMENT, EdgeLabelPlacement.HEAD);
        }
        
        // Configure the rendering
        KPolyline line = renderingFactory.createKPolyline();
        edge.getData().add(line);
        rendExt.setLineWidth(line, 2);
        rendExt.setForeground(line, colExt.getColor("#626262"));
        
        if (!undirected) {
            lineExt.addHeadArrowDecorator(line);
        }
        
        // TODO Add configuration for different line styles.
        
        return edge;
    }
    
    /**
     * Build a port.
     * 
     * @param portSide the side to assign to the new port
     * @param index the index to assign to the new port
     * @return a port
     */
    private KPort buildPort(PortSide portSide, int index) {
        KPort port = KGraphUtil.createInitializedPort();
        
        port.setSize(5, 5);
        port.setProperty(CoreOptions.PORT_SIDE, portSide);
        port.setProperty(CoreOptions.PORT_INDEX, index);
        
        KRectangle rectangle = renderingFactory.createKRectangle();
        port.getData().add(rectangle);
        rendExt.setForegroundInvisible(rectangle, true);
        rendExt.setBackground(rectangle, colExt.getColor("#808080"));
        
        return port;
    }

    
    ///////////////////////////////////////////////////////
    // Utility Methods
    
    /**
     * Checks if the configuration is valid.
     * 
     * @throws IllegalStateException if the configuration is invalid.
     */
    private void checkConfiguration() {
        // We need at least a source and a target node
        if (sourceNode == null || targetNode == null) {
            throw new IllegalStateException("source and target cannot be null");
        }
    }
    
    /**
     * Instantiates all KRendering extensions we need when adding a rendering to nodes.
     */
    private void injectExtensions() {
        if (renderingFactory == null) {
            renderingFactory = KRenderingFactory.eINSTANCE;
            
            Injector injector = Guice.createInjector();
            colExt = injector.getInstance(KColorExtensions.class);
            lineExt = injector.getInstance(KPolylineExtensions.class);
            rendExt = injector.getInstance(KRenderingExtensions.class);
        }
    }
}
