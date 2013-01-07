package de.cau.cs.kieler.klighd.debug.transformations

import de.cau.cs.kieler.core.kgraph.KNode
import de.cau.cs.kieler.core.krendering.KRenderingFactory
import de.cau.cs.kieler.core.krendering.KText
import de.cau.cs.kieler.core.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KPolylineExtensions
import de.cau.cs.kieler.core.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.core.util.Pair
import de.cau.cs.kieler.kiml.options.Direction
import de.cau.cs.kieler.kiml.options.LayoutOptions
import de.cau.cs.kieler.kiml.util.KimlUtil
import de.cau.cs.kieler.klighd.TransformationContext
import de.cau.cs.kieler.klighd.debug.visualization.AbstractDebugTransformation
import java.util.LinkedList
import org.eclipse.debug.core.model.IVariable

import static de.cau.cs.kieler.klighd.debug.transformations.DefaultTransformation.*
import javax.inject.Inject

class DefaultTransformation extends AbstractDebugTransformation {
       
    @Inject 
    extension KPolylineExtensions   
    @Inject
    extension KNodeExtensions
    @Inject
    extension KEdgeExtensions
    @Inject
    extension KRenderingExtensions

    private static val KRenderingFactory renderingFactory = KRenderingFactory::eINSTANCE

    override transform(IVariable model, TransformationContext<IVariable,KNode> transformationContext) {
        use(transformationContext)
        return KimlUtil::createInitializedNode() => [
                 it.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.klay.layered");
                 it.addLayoutParam(LayoutOptions::SPACING, 75f);
                 it.addLayoutParam(LayoutOptions::DIRECTION, Direction::UP);
                 if (model.referenceTypeName.endsWith("[]")) {
            // Array
                it.children += it.arrayTransform(model)
            }  else
                // Types without a transformation
                it.children += node.createValueNode(model,getValueText(model.type,model.getValueByName("")))
               ]
    }
    
    def KNode arrayTransform(KNode node, IVariable choice) {
        if (choice.type.endsWith("[]")) {
            val result = node.createValueNode(choice,getTypeText(choice.type))
            choice.value.variables.forEach[IVariable variable |
                node.children += node.arrayTransform(variable)
                choice.createEdge(variable)
            ]
            return result
        }
        else {
            val result = choice.createNode().putToLookUpWith(choice) => [
                it.setNodeSize(80,80);
                it.data += renderingFactory.createKRectangle() => [
                    it.childPlacement = renderingFactory.createKGridPlacement()
                ]
            ]
            result.nextTransformation(choice,null);
            return result;
        }
            
    }
    
    def KNode createValueNode(KNode node, IVariable variable, LinkedList<KText> text) {
        return variable.createNode().putToLookUpWith(variable) => [
            it.setNodeSize(80,80);
            it.data += renderingFactory.createKRectangle() => [
                it.childPlacement = renderingFactory.createKGridPlacement()
                text.forEach[
                    KText t |
                    it.children += t
                ]
            ]
        ]
    }
    
    def createEdge(KNode first, IVariable second) {
        return new Pair(first,second).createEdge() => [
            it.source = first 
            it.target = second.node
            it.data += renderingFactory.createKPolyline() => [
                it.setLineWidth(2);
                it.addArrowDecorator();
            ];
        ];
    }
    
    def createEdge(IVariable first, IVariable second) {
        return new Pair(first,second).createEdge() => [
            it.source = first.node 
            it.target = second.node
            it.data += renderingFactory.createKPolyline() => [
                it.setLineWidth(2);
                it.addArrowDecorator();
            ];
        ];
    }
        
    def LinkedList<KText> getValueText(String type, String value) {
        return new LinkedList<KText>() => [
            it += renderingFactory.createKText() => [
                it.text = "<<"+type+">>"
                it.setForegroundColor(120,120,120)
            ]
            it += renderingFactory.createKText() => [
                it.text = value
            ]
        ]
    }
    
    def LinkedList<KText> getTypeText(String type) {
        return new LinkedList<KText>() => [
            it += renderingFactory.createKText() => [
                it.text = type
            ]
        ]
    }   
    
}